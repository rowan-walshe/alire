package Alr.Commands.Pin is

   type Command is new Commands.Command with private;

   overriding
   procedure Execute (Cmd : in out Command);

   overriding
   function Long_Description (Cmd : Command)
                              return Alire.Utils.String_Vector;

   overriding
   function Short_Description (Cmd : Command) return String
   is ("Pin dependencies to exact versions");

   overriding
   procedure Setup_Switches
     (Cmd    : in out Command;
      Config : in out GNAT.Command_Line.Command_Line_Configuration);

   overriding
   function Usage_Custom_Parameters (Cmd : Command) return String
   is ("[[crate[=<version>]] | --all]");

private

   type Command is new Commands.Command with record
      Pin_All : aliased Boolean;
      Unpin   : aliased Boolean;
   end record;

end Alr.Commands.Pin;
