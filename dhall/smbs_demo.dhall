-- Demonstration of encoding the SMBS-format in Dhall.

let Prelude =
      https://prelude.dhall-lang.org/v19.0.0/package.dhall sha256:eb693342eb769f782174157eba9b5924cf8ac6793897fc36a31ccbd6f56dafe2

let List/map = Prelude.List.map

let List/concat = Prelude.List.concat

let Text/concatMap = Prelude.Text.concatMap

let Natural/equal = Prelude.Natural.equal

let Address = Text

let CommandCode = Text

let Data = Text

let Retries = Natural

let Milliseconds = Natural

let SMBusOptions =
      { Type = { use_pec : Bool, retries : Retries, comment : Optional Text }
      , default = { use_pec = True, retries = 1, comment = None Text }
      }

let SendByteArgs
    : Type
    = { data : Data, opts : SMBusOptions.Type }

let WriteArgs
    : Type
    = { code : CommandCode, data : Data, opts : SMBusOptions.Type }

let ReadArgs
    : Type
    = { code : CommandCode, opts : SMBusOptions.Type }

let SMBusCommand =
      -- A subset of the SMBus protocols supported by SMBS
      < SendByte : SendByteArgs
      | WriteByte : WriteArgs
      | WriteWord : WriteArgs
      | ReadByte : ReadArgs
      | ReadWord : ReadArgs
      >

let BlockOptions = { Type = { retries : Retries }, default.retries = 1 }

let Command
    -- The type of a value representing an SMBS statement
    : Type
    = ∀(Command : Type) →
      ∀(SetAddress : Address → Command) →
      ∀(SendReceive : SMBusCommand → Command) →
      ∀(Delay : Milliseconds → Command) →
      ∀(TransactionBlock : BlockOptions.Type → List Command → Command) →
        Command

let setAddress
    -- Set the active SMBus address
    : Address → Command
    = λ(addr : Address) →
      λ(Command : Type) →
      λ(SetAddress : Address → Command) →
      λ(SendReceive : SMBusCommand → Command) →
      λ(Delay : Milliseconds → Command) →
      λ(TransactionBlock : BlockOptions.Type → List Command → Command) →
        SetAddress addr

let sendReceive
    -- Helper function for creating SMBus command statements
    : SMBusCommand → Command
    = λ(cmd : SMBusCommand) →
      λ(Command : Type) →
      λ(SetAddress : Address → Command) →
      λ(SendReceive : SMBusCommand → Command) →
      λ(Delay : Milliseconds → Command) →
      λ(TransactionBlock : BlockOptions.Type → List Command → Command) →
        SendReceive cmd

let delay
    -- Delay statement
    : Milliseconds → Command
    = λ(t : Milliseconds) →
      λ(Command : Type) →
      λ(SetAddress : Address → Command) →
      λ(SendReceive : SMBusCommand → Command) →
      λ(Delay : Milliseconds → Command) →
      λ(TransactionBlock : BlockOptions.Type → List Command → Command) →
        Delay t

let transactionBlock_O
    -- Nested block of statements (w/ options)
    : BlockOptions.Type → List Command → Command
    = λ(opts : BlockOptions.Type) →
      λ(block : List Command) →
      λ(_Command : Type) →
      λ(SetAddress : Address → _Command) →
      λ(SendReceive : SMBusCommand → _Command) →
      λ(Delay : Milliseconds → _Command) →
      λ(TransactionBlock : BlockOptions.Type → List _Command → _Command) →
        let adapt
            : Command → _Command
            = λ(x : Command) →
                x _Command SetAddress SendReceive Delay TransactionBlock

        in  TransactionBlock opts (List/map Command _Command adapt block)

let transactionBlock
    -- Nested block of statements (w/o options)
    : List Command → Command
    = transactionBlock_O BlockOptions::{=}

let sendByte_O
    -- Send Byte (w/ options)
    : Data → SMBusOptions.Type → Command
    = λ(data : Data) →
      λ(opts : SMBusOptions.Type) →
        sendReceive (SMBusCommand.SendByte { data, opts })

let sendByte
    -- Send Byte (w/o options)
    : Data → Command
    = λ(data : Data) → sendByte_O data SMBusOptions::{=}

let writeByte_O
    -- Write Byte (w/ options)
    : CommandCode → Data → SMBusOptions.Type → Command
    = λ(cmd : CommandCode) →
      λ(data : Data) →
      λ(opts : SMBusOptions.Type) →
        sendReceive (SMBusCommand.WriteByte { code = cmd, data, opts })

let writeByte
    -- Write Byte (w/o options)
    : CommandCode → Data → Command
    = λ(cmd : CommandCode) →
      λ(data : Data) →
        writeByte_O cmd data SMBusOptions::{=}

let writeWord_O
    -- Write Word (w/ options)
    : CommandCode → Data → SMBusOptions.Type → Command
    = λ(cmd : CommandCode) →
      λ(data : Data) →
      λ(opts : SMBusOptions.Type) →
        sendReceive (SMBusCommand.WriteWord { code = cmd, data, opts })

let writeWord
    -- Write Word (w/o options)
    : CommandCode → Data → Command
    = λ(cmd : CommandCode) →
      λ(data : Data) →
        writeWord_O cmd data SMBusOptions::{=}

let readByte_O
    -- Read Byte (w/ options)
    : CommandCode → SMBusOptions.Type → Command
    = λ(cmd : CommandCode) →
      λ(opts : SMBusOptions.Type) →
        sendReceive
          (SMBusCommand.ReadByte { code = cmd, opts = SMBusOptions::{=} })

let readByte
    -- Read Byte (w/o options)
    : CommandCode → Command
    = λ(cmd : CommandCode) → readByte_O cmd SMBusOptions::{=}

let readWord_O
    -- Read Word (w/ options)
    : CommandCode → SMBusOptions.Type → Command
    = λ(cmd : CommandCode) →
      λ(opts : SMBusOptions.Type) →
        sendReceive (SMBusCommand.ReadWord { code = cmd, opts })

let readWord
    -- Read Word (w/o options)
    : CommandCode → Command
    = λ(cmd : CommandCode) → readWord_O cmd SMBusOptions::{=}

let indent = λ(t : Text) → "  " ++ t

let render_opts
    -- Helper function to render SMBusOptions
    : SMBusOptions.Type → Text
    = λ(opts : SMBusOptions.Type) →
            ( if    Natural/equal opts.retries 1
              then  ""
              else  " retries=" ++ Natural/show opts.retries
            )
        ++  (if opts.use_pec then "" else " ignore_pec")
        ++  merge
              { None = "", Some = λ(c : Text) → "        # " ++ c }
              opts.comment

let render_smbusCommand
    -- Render an SMBus command statement
    : SMBusCommand → Text
    = λ(smb : SMBusCommand) →
        merge
          { SendByte =
              λ(args : SendByteArgs) →
                args.data ++ " SEND_BYTE" ++ render_opts args.opts
          , WriteByte =
              λ(args : WriteArgs) →
                    args.code
                ++  " WRITE_BYTE "
                ++  args.data
                ++  render_opts args.opts
          , WriteWord =
              λ(args : WriteArgs) →
                    args.code
                ++  " WRITE_WORD "
                ++  args.data
                ++  render_opts args.opts
          , ReadByte =
              λ(args : ReadArgs) →
                args.code ++ " READ_BYTE" ++ render_opts args.opts
          , ReadWord =
              λ(args : ReadArgs) →
                args.code ++ " READ_WORD" ++ render_opts args.opts
          }
          smb

let render_lines
    -- Render a statement into a list of lines
    : Command → List Text
    = λ(cmd : Command) →
        let render_setAddress
            : Address → List Text
            = λ(addr : Address) → [ "SET ADDRESS " ++ addr ]

        let render_sendReceive
            : SMBusCommand → List Text
            = λ(smb : SMBusCommand) → [ render_smbusCommand smb ]

        let render_delay
            : Milliseconds → List Text
            = λ(t : Milliseconds) → [ "DELAY " ++ Natural/show t ]

        let render_block_opts
            : BlockOptions.Type → Text
            = λ(opts : BlockOptions.Type) →
                if    Natural/equal opts.retries 1
                then  ""
                else  " retries=" ++ Natural/show opts.retries

        let render_transactionBlock
            : BlockOptions.Type → List (List Text) → List Text
            = λ(opts : BlockOptions.Type) →
              λ(cs : List (List Text)) →
                  [ "BEGIN TRANSACTION" ++ render_block_opts opts ]
                # List/map Text Text indent (List/concat Text cs)
                # [ "END TRANSACTION" ]

        in  cmd
              (List Text)
              render_setAddress
              render_sendReceive
              render_delay
              render_transactionBlock

let render
    -- Render a statement into a Text value
    : Command → Text
    = λ(cmd : Command) →
        Text/concatMap Text (λ(line : Text) → line ++ "\n") (render_lines cmd)

let example
    : Command
    = transactionBlock
        [ setAddress "40"
        , sendByte_O "03" SMBusOptions::{ comment = Some "CLEAR_FAULTS" }
        , writeByte "00" "12"
        , delay 200
        , writeWord "D7" "4321"
        , transactionBlock_O
            { retries = 5 }
            [ writeByte "25" "55"
            , writeWord "88" "ABCD"
            , writeWord_O "89" "BCDE" SMBusOptions::{ use_pec = False }
            , writeWord "8A" "CDEF"
            , readByte "00"
            ]
        , writeWord_O "03" "7777" SMBusOptions::{ retries = 3 }
        , delay 500
        ]

in  render example
{-

$ dhall text --file smbs.dhall

Output:

BEGIN TRANSACTION
  SET ADDRESS 40
  03 SEND_BYTE        # CLEAR_FAULTS
  00 WRITE_BYTE 12
  DELAY 200
  D7 WRITE_WORD 4321
  BEGIN TRANSACTION retries=5
    25 WRITE_BYTE 55
    88 WRITE_WORD ABCD
    89 WRITE_WORD BCDE ignore_pec
    8A WRITE_WORD CDEF
    00 READ_BYTE
  END TRANSACTION
  03 WRITE_WORD 7777 retries=3
  DELAY 500
END TRANSACTION

-}
