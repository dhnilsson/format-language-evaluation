-- device-max9000.dhall

{- This demonstration file represents a set of 
   device-centric functions used in conjunction 
   with a system file. They could be provided
   and signed by a device vendor.

   Note: Theoretically you could DRY things further
   by having a function along the lines of
   "let writeConfigurationOrVerifySteps" referenced
   by the respective config/verify methods.
-}

let checkIfDisabled = \(args: {channel : Text, address : Natural}) ->
    { 
        description = "Configure device for 3.3V operation.",
        operation_type = "smbus_operation",
        operation_error_handling = "break_on_error",
        channel = args.channel,
        smbus_address = args.address,
        smbus_operation_structure = [
            "command_code", "transaction_type", "write_data", "expect_data", "and_mask", "use_pec"],
        smbus_operation_steps = [
            ["0x01", "read_byte" , "null"   , "0x00", "0x80" , "false"] -- OPERATION, evaluate bit 7
        ]
    }

let writeConfiguration = \(args: {channel : Text, address : Natural}) ->
    { 
        description = "Configure device for 3.3V operation.",
        operation_type = "smbus_operation",
        operation_error_handling = "break_on_error",
        channel = args.channel,
        smbus_address = args.address,
        smbus_operation_structure = [
            "command_code", "transaction_type", "write_data", "use_pec"
            ],
        smbus_operation_steps = [
            ["0x21", "write_word" , "0x699A", "false"], -- VOUT_COMMAND: 3.3V 
            ["0x15", "send_byte"  , "null"  , "false"], -- STORE_USER_ALL
            ["null", "delay_in_ms", "10" , "false"] -- A hack to deal with IC's requiring txn delays / fit within mapping
        ]
    }

let makeConfiguration = \(args: {description : Text, channel : Text, address : Natural}) ->
    let description = args.description
    let disableCheck = checkIfDisabled { 
        channel = args.channel, 
        address = args.address 
    }
    let writeConfig = writeConfiguration { 
        channel = args.channel, 
        address = args.address 
    }
    in  { description,
          operation_type = "composition",
          composition_operation_steps_order = [
            "disableCheck",
            "writeConfig"
          ],
          composition_operation_steps = {
            disableCheck,
            writeConfig
          }
        }


-- TODO let writeVerify = \(args: {description: Text}) ->

-- TODO
let makeVerify = \(args: {description : Text, channel : Text, address : Natural}) ->
    let description = args.description
    let channel = args.channel
    in  { description,
          channel
        }

-- TODO
let makePresence = \(args: {description : Text, channel : Text, address : Natural}) ->
    let description = args.description
    let channel = args.channel
    in  { description,
          channel
        }

-- EXPORT FUNCTIONS FOR USE IN SYSTEM FILE
-- Note how I only expose the make-related functions

in {makeConfiguration, makeVerify, makePresence}