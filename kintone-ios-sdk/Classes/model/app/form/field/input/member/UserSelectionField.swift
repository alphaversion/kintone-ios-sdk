// Copyright (c) 2018 Cybozu, Inc.

open class UserSelectionField: AbstractMemberSelectField {
    
    public init (_ code: String) {
        super.init()
        self.code = code
        self.type = FieldType.USER_SELECT
    }
    
    public required init(from decoder: Decoder) throws {
      try super.init(from: decoder)
    }
    
    override open func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}
