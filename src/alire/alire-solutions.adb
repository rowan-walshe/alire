with Alire.Crates.With_Releases;
with Alire.Dependencies;
with Alire.Releases;
with Alire.Solutions.Diffs;
with Alire.Utils.Tables;

package body Alire.Solutions is

   -------------
   -- Changes --
   -------------

   function Changes (Former, Latter : Solution) return Diffs.Diff is
     (Diffs.Between (Former, Latter));

   ------------------
   -- Changing_Pin --
   ------------------

   function Changing_Pin (This   : Solution;
                          Name   : Crate_Name;
                          Pinned : Boolean) return Solution
   is
      --  This temporary works around a tampering check
      New_Releases : constant Release_Map :=
                       This.Releases.Including
                         (This.Releases (Name).With_Pin (Pinned));
   begin
      return This : Solution := Changing_Pin.This do
         This.Releases := New_Releases;
      end return;
   end Changing_Pin;

   ----------
   -- Pins --
   ----------

   function Pins (This : Solution) return Conditional.Dependencies is
      use type Conditional.Dependencies;
   begin
      if not This.Valid then
         return Conditional.No_Dependencies;
      end if;

      return Dependencies : Conditional.Dependencies do
         for Release of This.Releases loop
            if Release.Is_Pinned then
               Dependencies :=
                 Dependencies and
                 Conditional.New_Dependency (Release.Name,
                                             Release.Version);
            end if;
         end loop;
      end return;
   end Pins;

   ----------------
   -- Print_Pins --
   ----------------

   procedure Print_Pins (This : Solution) is
      Table : Utils.Tables.Table;
   begin
      if not (for some Release of This.Releases => Release.Is_Pinned) then
         Trace.Always ("There are no pins");
      else
         for Release of This.Releases loop
            if Release.Is_Pinned then
               Table
                 .Append (+Release.Name)
                 .Append (Release.Version.Image)
                 .New_Row;
            end if;
         end loop;

         Table.Print (Always);
      end if;
   end Print_Pins;

   --------------
   -- Required --
   --------------

   function Required (This : Solution) return Containers.Crate_Name_Sets.Set is
   begin
      if not This.Valid then
         return Containers.Crate_Name_Sets.Empty_Set;
      end if;

      --  Merge release and hint crates

      return Set : Containers.Crate_Name_Sets.Set do
         for Dep of This.Hints loop
            Set.Include (Dep.Crate);
         end loop;

         for Rel of This.Releases loop
            Set.Include (Rel.Name);
         end loop;
      end return;
   end Required;

   ---------------
   -- With_Pins --
   ---------------

   function With_Pins (This, Src : Solution) return Solution is
   begin
      return This : Solution := With_Pins.This do
         if not Src.Valid then
            return;
         end if;

         for Release of Src.Releases loop
            if Release.Is_Pinned then
               This.Releases (Release.Name).Pin;
            end if;
         end loop;
      end return;
   end With_Pins;

   ----------
   -- Keys --
   ----------

   package Keys is

      --  TOML keys used locally for loading and saving of solutions

      Advisory     : constant String := "advisory";
      Context      : constant String := "context";
      Dependencies : constant String := "dependency";
      Externals    : constant String := "externals";
      Valid        : constant String := "valid";

   end Keys;

   ---------------
   -- From_TOML --
   ---------------

   function From_TOML (From : TOML_Adapters.Key_Queue)
                       return Solution
   is
      --  We are parsing an internally generated structure, so any errors in it
      --  are unexpected.
   begin
      Trace.Debug ("Reading solution from TOML...");
      if From.Unwrap.Get (Keys.Context).Get (Keys.Valid).As_Boolean then
         return This : Solution (Valid => True) do
            Assert (From_TOML (This, From));
         end return;
      else
         Trace.Debug ("Read invalid solution from TOML");
         return (Valid => False);
      end if;
   end From_TOML;

   ---------------
   -- From_TOML --
   ---------------

   overriding
   function From_TOML (This : in out Solution;
                       From :        TOML_Adapters.Key_Queue)
                       return Outcome
   is
      use TOML;

      ------------------
      -- Read_Release --
      ------------------
      --  Load a single release. From points to the crate name, which contains
      --  crate.general and crate.version tables.
      function Read_Release (From : TOML_Value) return Alire.Releases.Release
      is
         Name  : constant String := +From.Keys (1);
         Crate : Crates.With_Releases.Crate :=
                   Crates.With_Releases.New_Crate (+Name);

         --  We can proceed loading the crate normally
         OK    : constant Outcome :=
                   Crate.From_TOML
                     (From_TOML.From.Descend
                        (Value   => From.Get (Name),
                         Context => "crate"));
      begin

         --  Double checks

         if From.Keys'Length /= 1 then
            From_TOML.From.Checked_Error ("too many keys in stored crate");
         end if;

         OK.Assert;

         if Crate.Releases.Length not in 1 then
            From_TOML.From.Checked_Error
              ("expected a single release, but found"
               & Crate.Releases.Length'Img);
         end if;

         return Crate.Releases.First_Element;
      end Read_Release;

   begin
      if not From.Unwrap.Get (Keys.Context).Get (Keys.Valid).As_Boolean then
         From.Checked_Error ("cannot load invalid solution");
      end if;

      Trace.Debug ("Reading valid solution from TOML...");

      --  Load proper releases, stored as a crate with a single release

      declare
         Releases     : TOML_Value;
         Has_Releases : constant Boolean :=
                          From.Pop (Keys.Dependencies, Releases);
      begin
         if Has_Releases then -- must be an array
            for I in 1 .. Releases.Length loop
               This.Releases.Insert (Read_Release (Releases.Item (I)));
            end loop;
         end if;
      end;

      --  Load external dependencies

      declare
         Externals     : TOML_Value;
         Has_Externals : constant Boolean :=
                           From.Pop (Keys.Externals, Externals);
      begin
         if Has_Externals then -- It's a table containing dependencies
            for I in 1 .. Externals.Keys'Length loop
               This.Hints.Merge
                 (Dependencies.From_TOML
                    (Key   => +Externals.Keys (I),
                     Value => Externals.Get (Externals.Keys (I))));
            end loop;
         end if;
      end;

      return Outcome_Success;
   end From_TOML;

   -------------
   -- To_TOML --
   -------------

   function To_TOML (This : Solution;
                     Props : Properties.Vector) return TOML.TOML_Value
   is
      Static_Solution : Solution := This;
   begin
      if This.Valid then
         Static_Solution.Releases := This.Releases.Whenever (Props);
      end if;

      return To_TOML (Static_Solution);
   end To_TOML;

   -------------
   -- To_TOML --
   -------------

   overriding
   function To_TOML (This : Solution) return TOML.TOML_Value is
      use TOML;
   begin

      --  The structure used to store a solution is:
      --
      --  [context]
      --  Validity, advisory
      --
      --  [[dependency.crate_name.version]]
      --  Dependency release description
      --
      --  [externals]
      --  crate_name = "version set"
      --  ...

      return Root : constant TOML_Value := Create_Table do

         --  Output advisory and validity

         declare
            Context : constant TOML_Value := Create_Table;
         begin
            Root.Set (Keys.Context, Context);
            Context.Set
              (Keys.Advisory,
               Create_String
                 ("THIS IS AN AUTOGENERATED FILE. DO NOT EDIT MANUALLY"));
            Context.Set (Keys.Valid, Create_Boolean (This.Valid));
         end;

         --  Early exit when the solution is invalid

         if not This.Valid then
            return;
         end if;

         --  Output proper releases (except detected externals, which will be
         --  output as external hints)

         declare
            Deps : constant TOML_Value := Create_Array (TOML_Table);
         begin
            for Dep of This.Releases loop
               declare
                  Release : constant TOML_Value := Create_Table;
               begin
                  Deps.Append (Release);
                  Release.Set (Dep.Name_Str, Dep.To_TOML);
               end;
            end loop;

            Root.Set (Keys.Dependencies, Deps);
         end;

         --  Output external releases

         declare
            Externals : constant TOML_Value := Create_Table;
         begin
            if not This.Hints.Is_Empty then
               for Dep of This.Hints loop
                  Externals.Set (+Dep.Crate, Dep.To_TOML);
               end loop;

               Root.Set (Keys.Externals, Externals);
            end if;
         end;

      end return;
   end To_TOML;

end Alire.Solutions;
