with GNAT.Command_Line;

with Alire.Directories;
with Alire.Roots.Optional;
with Alire.Solver;
with Alire.Utils;

private with Ada.Text_IO;

private with Alire.GPR;

pragma Warnings (Off);
private with Alr.OS_Lib; -- For the benefit of many child packages that use it
pragma Warnings (On);
private with Alr.Utils;

package Alr.Commands is

   Wrong_Command_Arguments : exception;

   -------------
   -- Execute --
   -------------

   procedure Execute;
   --  Entry point into alr, will parse the command line and proceed as needed.

   -------------
   -- Command --
   -------------

   type Command is abstract tagged limited private;
   --  This type encapsulates configuration and execution of a specific
   --  command. It also has help-related subprograms. Help is structured as:
   --  1. SUMMARY, showing <one-liner explanation>
   --  <one-liner explanation> is provided by Short_Description (see below).
   --
   --  2. USAGE, "alr [global options] command [command options]" & [args text]
   --  [args text] is provided by Usage_Custom_Parameters (see below).
   --
   --  3. GLOBAL OPTIONS explanation.
   --  Autogenerated by GNAT.Command_Line.
   --  Global arguments are set up by alr for all commands.
   --
   --  4. COMMAND OPTIONS explanation (if existing).
   --  Autogenerated by GNAT.Command_Line.
   --  Command switches are set up by each command with Setup_Switches (below).
   --
   --  5. DESCRIPTION, custom detailed command explanation.
   --  Commands provide this text with Long_Description (see below).

   procedure Execute (Cmd : in out Command) is abstract;
   --  Commands must override this procedure to provide the command
   --  functionality. Should raise Command_Failed if command cannot be
   --  completed normally. Should raise Wrong_Command_Arguments if the
   --  arguments are incorrect.

   function Long_Description (Cmd : Command) return Alire.Utils.String_Vector
                              is abstract;
   --  Return a detailed description of the command. Each string in the vector
   --  is a paragraph that will be reformatted into appropriate length lines.

   procedure Setup_Switches
     (Cmd    : in out Command;
      Config : in out GNAT.Command_Line.Command_Line_Configuration)
   is null;
   --  Gets called once the command has been identified, but before the call to
   --  Execute. Config must be set up with the switches used by the command.

   function Short_Description (Cmd : Command) return String is abstract;
   --  One-liner displayed in the list of commands that alr understands that
   --  gets shown when no command or unknown command is given. Also shown as
   --  SUMMARY in the help of a specific command.

   function Usage_Custom_Parameters (Cmd : Command) return String is abstract;
   --  The part after "alr [global options] command [command options] " that
   --  gets shown in USAGE in the command help summary. That is, it is the
   --  specific command-line part that is not managed via Gnat.Command_Line

   -----------------------------------------
   -- Supporting subprograms for commands --
   -----------------------------------------

   function Root (Cmd : in out Command'Class)
                  return Alire.Roots.Optional.Reference;
   --  Using this call will ensure the Root detection has been attempted

   procedure Set (Cmd  : in out Command'Class;
                  Root : Alire.Roots.Root);
   --  Replace the current root in use by the command. Modifying the root via
   --  the Cmd.Root reference is valid and intended usage that does not require
   --  resetting the root.

   procedure Requires_Full_Index (Cmd          : in out Command'Class;
                                  Force_Reload : Boolean := False);
   --  Unless Force_Reload, if the index is not empty we no nothing

   procedure Requires_Valid_Session (Cmd          : in out Command'Class;
                                     Sync         : Boolean := True);
   --  Verifies that a valid working dir is in scope. After calling it,
   --  Cmd.Root will be usable if alr was run inside a Root. If Sync, enforce
   --  that the manifest, lockfile and dependencies on disk are in sync, by
   --  performing a silent update. If not Sync, only a minimal empty lockfile
   --  is created.

   ---------------------------
   --  command-line helpers --
   ---------------------------

   function Is_Quiet return Boolean;
   --  Says if -q was in the command line

   function Query_Policy return Alire.Solver.Age_Policies;
   --  Current policy

   --  Declared here so they are available to the help metacommand child
   --  package and Spawn.

   function Crate_Version_Sets return Alire.Utils.String_Vector;
   --  Returns the instructions to restrict version sets, for use in
   --  Long_Description help functions.

   type Cmd_Names is (Cmd_Build,
                      Cmd_Clean,
                      Cmd_Config,
                      Cmd_Dev,
                      Cmd_Edit,
                      Cmd_Get,
                      Cmd_Help,
                      Cmd_Index,
                      Cmd_Init,
                      Cmd_Pin,
                      Cmd_Printenv,
                      Cmd_Publish,
                      Cmd_Run,
                      Cmd_Search,
                      Cmd_Show,
                      Cmd_Test,
                      Cmd_Update,
                      Cmd_Version,
                      Cmd_With);
   --  The Cmd_ prefix allows the use of the proper name in child packages
   --  which otherwise cause conflict.
   --  It is a bit ugly but also it makes clear when we are using this
   --  enumeration.

   function Image (N : Cmd_Names) return String;

   type Group_Names is
     (Group_General,
      Group_Build,
      Group_Index,
      Group_Release,
      Group_Publish);

   function Image (Name : Group_Names) return String;

   Group_Commands : constant array (Cmd_Names) of Group_Names :=
     (Cmd_Config |
      Cmd_Help |
      Cmd_Printenv |
      Cmd_Version => Group_General,
      Cmd_Build |
      Cmd_Clean |
      Cmd_Dev |
      Cmd_Edit |
      Cmd_Run |
      Cmd_Test    => Group_Build,
      Cmd_Index   => Group_Index,
      Cmd_Get |
      Cmd_Init |
      Cmd_Pin |
      Cmd_Search |
      Cmd_Show |
      Cmd_Update |
      Cmd_With    => Group_Release,
      Cmd_Publish => Group_Publish);

   function Enter_Working_Folder return Alire.Directories.Destination;
   --  Attempt to find the root alire working dir if deeper inside it

private

   type Command is abstract tagged limited record
      Optional_Root : Alire.Roots.Optional.Root;
   end record;

   --  Facilities for command/argument identification. These are available to
   --  commands.

   procedure Reportaise_Command_Failed  (Message : String);
   procedure Reportaise_Wrong_Arguments (Message : String);
   --  Report and Raise :P

   Raw_Arguments : Utils.String_Vector;
   --  Raw arguments, first one is the command

   function Is_Command (Str : String) return Boolean;
   --  Say if string matches an alr command

   function What_Command return String;
   function What_Command (Str : String := "") return Cmd_Names;
   --  Return the command for the given string, or use the first non-switch
   --  command-line argument if Str = "".

   function Num_Arguments return Natural;
   --  Actual arguments besides the command
   function Argument (I : Positive) return String; -- May raise if not existing

   Scenario : Alire.GPR.Scenario;
   --  This will be filled in during parsing of command line with any seen "-X"
   --  parameters.

   --  Other options

   procedure Display_Usage (Cmd : Cmd_Names);

   procedure Display_Global_Options;

   procedure Display_Valid_Commands;

   procedure Execute_By_Name (Cmd : Cmd_Names);
   --  Execute a command with the externally given command line

   --  Folder guards conveniences for commands:

   subtype Folder_Guard is Alire.Directories.Guard;

   function Enter_Folder (Path : String) return Alire.Directories.Destination
   renames Alire.Directories.Enter;

   --  Common generalities

   procedure New_Line (Spacing : Ada.Text_IO.Positive_Count := 1)
   renames Ada.Text_IO.New_Line;

   procedure Put_Line (S : String)
   renames Ada.Text_IO.Put_Line;

end Alr.Commands;
