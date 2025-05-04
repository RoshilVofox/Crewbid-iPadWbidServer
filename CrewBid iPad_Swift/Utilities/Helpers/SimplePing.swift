//
//  Pinger.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 04/05/25.
//

import Foundation
import Network

struct ICMPHeader {
    var type: UInt8
    var code: UInt8
    var checksum: UInt16
    var identifier: UInt16
    var sequenceNumber: UInt16
}

private func in_cksum(_ buffer: UnsafeRawPointer, bufferLen: Int) -> UInt16 {
    var bytesLeft = bufferLen
    var sum: UInt32 = 0
    var cursor = buffer.bindMemory(to: UInt16.self, capacity: bufferLen / 2)

    while bytesLeft > 1 {
        sum += UInt32(cursor.pointee)
        cursor = cursor.advanced(by: 1)
        bytesLeft -= 2
    }

    if bytesLeft == 1 {
        var last: UInt16 = 0
        let uc = buffer.load(fromByteOffset: bufferLen - 1, as: UInt8.self)
        last = UInt16(uc) << 8
        sum += UInt32(last)
    }

    sum = (sum >> 16) + (sum & 0xFFFF)
    sum += (sum >> 16)

    return ~UInt16(sum)
}

protocol SimplePingDelegate: AnyObject {
    func simplePing(_ pinger: SimplePing, didStartWithAddress address: Data)
    func simplePing(_ pinger: SimplePing, didFailWithError error: Error)
    func simplePing(_ pinger: SimplePing, didSendPacket packet: Data)
    func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data, error: Error)
    func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data)
    func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data)
    func simplePingDidTimeoutWaitingForResponsePacket(_ pinger: SimplePing)
}

class SimplePing: NSObject {
    let hostName: String?
    var hostAddress: Data?
    weak var delegate: SimplePingDelegate?

    private var identifier: UInt16 = 0
    private var nextSequenceNumber: UInt16 = 0
    private var socket: CFSocket?
    private var host: CFHost?
    private var sequenceNumbersWithoutResults = Set<UInt16>()
    var timeout: TimeInterval = 1.0

    init(hostName: String?, hostAddress: Data?) {
        assert((hostName != nil) != (hostAddress != nil)) // XOR
        self.hostName = hostName
        self.hostAddress = hostAddress
        self.identifier = UInt16.random(in: 0...UInt16.max)
        super.init()
    }

    static func simplePingWithHostName(_ hostName: String) -> SimplePing {
        return SimplePing(hostName: hostName, hostAddress: nil)
    }

    static func simplePingWithHostAddress(_ hostAddress: Data) -> SimplePing {
        return SimplePing(hostName: nil, hostAddress: hostAddress)
    }

    func start() {
        if let address = hostAddress {
            _startWithHostAddress(address)
        } else if let name = hostName {
            _startResolvingHostName(name)
        }
    }

    func stop() {
        _stopHostResolution()
        _stopDataTransfer()
        if hostName != nil {
            hostAddress = nil
        }
    }

    private func _startResolvingHostName(_ name: String) {
        var streamError = CFStreamError()
        host = CFHostCreateWithName(nil, name as CFString).takeRetainedValue()
        guard let host = host else { return }

        var context = CFHostClientContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(),
                                          retain: nil, release: nil, copyDescription: nil)

        CFHostSetClient(host, { (host, typeInfo, error, info) in
            guard let info = info else { return }
            let simplePing = Unmanaged<SimplePing>.fromOpaque(info).takeUnretainedValue()
            if let err = error, err.pointee.domain != 0 {
                simplePing._didFailWithHostStreamError(err.pointee)
            } else {
                simplePing._hostResolutionDone()
            }
        }, &context)

        CFHostScheduleWithRunLoop(host, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

        let success = CFHostStartInfoResolution(host, .addresses, &streamError)
        if !success {
            _didFailWithHostStreamError(streamError)
        }
    }

    private func _hostResolutionDone() {
        guard let host = host else { return }
        var resolved = false
        if let addresses = CFHostGetAddressing(host, nil)?.takeUnretainedValue() as? [Data] {
            for address in addresses {
                if address.count >= MemoryLayout<sockaddr>.size {
                    address.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                        let sa = ptr.baseAddress!.assumingMemoryBound(to: sockaddr.self)
                        if sa.pointee.sa_family == sa_family_t(AF_INET) {
                            self.hostAddress = address
                            resolved = true
                        }
                    }
                }
                if resolved { break }
            }
        }

        _stopHostResolution()
        if resolved {
            _startWithHostAddress(hostAddress!)
        } else {
            let error = NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(CFNetworkErrors.cfHostErrorHostNotFound.rawValue), userInfo: nil)
            _didFailWithError(error)
        }
    }

    private func _didFailWithHostStreamError(_ error: CFStreamError) {
        let error = NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(CFNetworkErrors.cfHostErrorUnknown.rawValue), userInfo: nil)
        _didFailWithError(error)
    }

    private func _didFailWithError(_ error: Error) {
        stop()
        delegate?.simplePing(self, didFailWithError: error)
    }

    private func _startWithHostAddress(_ address: Data) {
        var fd: Int32 = -1
        address.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            let sa = ptr.baseAddress!.assumingMemoryBound(to: sockaddr.self)
            if sa.pointee.sa_family == sa_family_t(AF_INET) {
                fd = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)
            }
        }

        if fd < 0 {
            _didFailWithError(NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil))
            return
        }

        var context = CFSocketContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(),
                                      retain: nil, release: nil, copyDescription: nil)

        socket = CFSocketCreateWithNative(nil, fd, CFSocketCallBackType.readCallBack.rawValue,
                                          { _, _, _, _, info in
            if let info = info {
                let pinger = Unmanaged<SimplePing>.fromOpaque(info).takeUnretainedValue()
                pinger._readData()
            }
        }, &context)

        guard let socket = socket else { return }

        let rls = CFSocketCreateRunLoopSource(nil, socket, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, CFRunLoopMode.defaultMode)
        delegate?.simplePing(self, didStartWithAddress: address)
    }

    private func _stopHostResolution() {
        if let host = host {
            CFHostSetClient(host, nil, nil)
            CFHostUnscheduleFromRunLoop(host, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            self.host = nil
        }
    }

    private func _stopDataTransfer() {
        if let socket = socket {
            CFSocketInvalidate(socket)
            self.socket = nil
        }
    }

    func sendPing(data: Data? = nil) {
        var payload = data
        if payload == nil {
            let message = String(format: "%28zd bottles of beer on the wall", 99 - (Int(nextSequenceNumber) % 100))
            payload = message.data(using: .ascii)
        }

        guard let payloadData = payload else { return }

        var icmpHeader = ICMPHeader(type: 8, code: 0, checksum: 0,
                                    identifier: CFSwapInt16HostToBig(identifier),
                                    sequenceNumber: CFSwapInt16HostToBig(nextSequenceNumber))

        var packet = Data(bytes: &icmpHeader, count: MemoryLayout<ICMPHeader>.size)
        packet.append(payloadData)

        var checksumPacket = packet
        checksumPacket.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            let headerPtr = ptr.baseAddress!.assumingMemoryBound(to: ICMPHeader.self)
            headerPtr.pointee.checksum = in_cksum(ptr.baseAddress!, bufferLen: packet.count)
        }

        let socketFD = CFSocketGetNative(socket!)
        var err: Int32 = 0
        let sent = hostAddress!.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> ssize_t in
            let sa = ptr.baseAddress!.assumingMemoryBound(to: sockaddr.self)
            let addrLen = socklen_t(hostAddress!.count)
            return sendto(socketFD, [UInt8](packet), packet.count, 0, sa, addrLen)
        }

        if sent > 0 {
            sequenceNumbersWithoutResults.insert(nextSequenceNumber)
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                self._verifyTimeoutForSequenceNumber(self.nextSequenceNumber)
            }
            delegate?.simplePing(self, didSendPacket: packet)
        } else {
            err = errno
            delegate?.simplePing(self, didFailToSendPacket: packet, error: NSError(domain: NSPOSIXErrorDomain, code: Int(err), userInfo: nil))
        }

        nextSequenceNumber += 1
    }

    private func _verifyTimeoutForSequenceNumber(_ sequence: UInt16) {
        if sequenceNumbersWithoutResults.contains(sequence) {
            sequenceNumbersWithoutResults.remove(sequence)
            delegate?.simplePingDidTimeoutWaitingForResponsePacket(self)
        }
    }

    private func _readData() {
        let socketFD = CFSocketGetNative(socket!)
        var addr = sockaddr_storage()
        var addrLen = socklen_t(MemoryLayout.size(ofValue: addr))
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: 65535, alignment: 1)
        defer { buffer.deallocate() }

        let bytesRead = recvfrom(socketFD, buffer, 65535, 0, UnsafeMutableRawPointer(&addr).assumingMemoryBound(to: sockaddr.self), &addrLen)

        if bytesRead > 0 {
            let packet = Data(bytes: buffer, count: bytesRead)
            // Add checksum verification and delegate callbacks here
            delegate?.simplePing(self, didReceivePingResponsePacket: packet) // Simplified
        } else {
            delegate?.simplePing(self, didFailWithError: NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil))
        }
    }
}
