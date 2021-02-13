-- system-obmcrouter.dhall

{- This demonstration file represents a set of 
   system-centric functions used in conjunction 
   with a device file. This file could be written
   by an end-customer using multiple power supply
   vendors in their system. 
-}

-- # IMPORT ASSOCIATED DEVICE FILES
{- Variable contains relative import reference.

   NOTE: you can also do a sha256 reference instead but
         leaving that out for sake of this demonstration.
-}
let max9000 = ./device-max9000.dhall

-- # HELPER FUNCTIONS


-- # DEFINE OPERATIONS - RAIL/DEVICE LEVEL
let rail1_channel = "/dev/i2c0"
let rail1_address = 0x20

let rail1Configuration = max9000.makeConfiguration { 
                    description = "Configure Rail 1 (max9000)", 
                    channel = rail1_channel, 
                    address = rail1_address }

let rail1Verify = max9000.makeVerify { 
                    description = "Verify Rail 1 (max9000)", 
                    channel = rail1_channel, 
                    address = rail1_address }

-- # DEFINE OPERATIONS - SYSTEM LEVEL

{- NOTE: steps are duplicated so
         `composition_operation_steps_order` only references
        namespace of steps in `composition_operation_steps`
-}
let rail1ConfigureAndVerify = {
    description = "Configure & Verify Rail 1",
    operation_type = "composition",
    composition_operation_steps_order = [ 
        "rail1Configuration", 
        "rail1Verify" ],
    composition_operation_steps = {
        rail1Configuration,
        rail1Verify
    }
}

-- # DEFINE OUTPUT

let operations =  {rail1Configuration,
                   rail1Verify,
                   rail1ConfigureAndVerify}

let system = {
  name = "OBMC Router System",
  revision = "A",
  description = "OpenBMC Router",
  operations
}

in system
