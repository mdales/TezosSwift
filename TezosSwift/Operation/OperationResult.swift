//
//  OperationResult.swift
//  TezosSwift
//
//  Created by Marek Fořt on 12/17/18.
//

import Foundation

enum OperationResultStatus {
    case failed(error: PreapplyError)
    case applied
}

enum OperationResultStatusValue: String, Codable {
    case failed
    case applied
}

public enum OperationErrorKind: String, Codable {
    case temporary
    case branch
    case permanent
}

public struct PreapplyError: Codable {
    public let kind: OperationErrorKind
    public let id: String
}

struct OperationResult {
    let consumedGas: Mutez?
    let operationResultStatus: OperationResultStatus
}

extension OperationResult: Decodable {
    private enum CodingKeys: String, CodingKey {
        case consumedGas = "consumed_gas"
        case status
        case storageSize
        case storage
        case errors
        case id
    }

    init(from decoder: Decoder) throws {
        func decodeError(with stringError: String) -> InjectReason {
            if stringError.contains("gas_exhausted") {
                return .gasExhaustion
            } else {
                return .unknown(message: stringError)
            }
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        consumedGas = try container.decodeIfPresent(Mutez.self, forKey: .consumedGas)
        let status = try container.decode(OperationResultStatusValue.self, forKey: .status)
        switch status {
        case .applied:
            operationResultStatus = .applied
        case .failed:
            var errorsUnkeyedContainer = try container.nestedUnkeyedContainer(forKey: .errors)
            let preapplyReasonError = try errorsUnkeyedContainer.decode(PreapplyError.self)
//            let stringError = try errorsUnkeyedContainer.nestedContainer(keyedBy: CodingKeys.self).decode(String.self, forKey: .id)
//            let operationError = decodeError(with: stringError)
            operationResultStatus = .failed(error: preapplyReasonError)
        }
    }
}

