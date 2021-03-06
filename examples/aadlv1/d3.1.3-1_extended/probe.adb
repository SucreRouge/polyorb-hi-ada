------------------------------------------------------------------------------
--                                                                          --
--                          PolyORB HI COMPONENTS                           --
--                                                                          --
--                                P R O B E                                 --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--    Copyright (C) 2006-2009 Telecom ParisTech, 2010-2018 ESA & ISAE.      --
--                                                                          --
-- PolyORB-HI is free software; you can redistribute it and/or modify under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion. PolyORB-HI is distributed in the hope that it will be useful, but  --
-- WITHOUT ANY WARRANTY; without even the implied warranty of               --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
--              PolyORB-HI/Ada is maintained by the TASTE project           --
--                      (taste-users@lists.tuxfamily.org)                   --
--                                                                          --
------------------------------------------------------------------------------

--  $Id: probe.adb 5381 2007-12-23 12:39:41Z zalila $

with Ada.Real_Time; use Ada.Real_Time;

with PolyORB_HI.Output;

package body Probe is

   use PolyORB_HI.Output;

   --  Variables used for the thread identities resoving

   GNC_Welcome  : Boolean := True;
   TMTC_Welcome : Boolean := True;

   --  At elaboration time, this package evaluate the number of fixed
   --  point operation 1.0 / X to consume CPU during 1 millisecond.

   --  We use fixed point types to be compliant with restrictions for
   --  HIgh-Integrity systems (pragma Restriction No_Float).

   type Fixed_12_6 is delta 1.0E-6 digits 12;

   N_Base : constant Natural     := 1_000;
   F_Base : constant Fixed_12_6  := 1.0001;

   --  XMS or X Milli Seconds
   XMS    : constant Time_Span := Milliseconds (1);
   N_XMS  : Natural; --  Is computed at elaboration time

   procedure Compute_During_N_Times_1ms (N : Natural);
   --  Consume CPU during N * 1 Millisecond

   --------------------------------
   -- Compute_During_N_Times_1ms --
   --------------------------------

   procedure Compute_During_N_Times_1ms (N : Natural) is
      X : Fixed_12_6 := F_Base;
   begin
      for I in 1 .. N_XMS * N loop
         X := 1.0 / X;
      end loop;
   end Compute_During_N_Times_1ms;

   ----------
   -- Read --
   ----------

   procedure Read
     (Read_Value :    out POS_Internal_Type;
      Field      : in out POS_Internal_Type)
   is
      pragma Warnings (Off, Field);
      --  To kill warning "mode could be "in" instead of "in out"
   begin
      Read_Value := Field;
      Put_Line ("Value Read: " & POS_Internal_Type'Image (Field));
   end Read;

   ------------
   -- Update --
   ------------

   procedure Update (Field : in out POS_Internal_Type) is
   begin
      Field := Field + 1;
      Put_Line ("Value Updated: " & POS_Internal_Type'Image (Field));
   end Update;

   -------------
   -- GNC_Job --
   -------------

   procedure GNC_Job is
   begin
      Put_Line ("Begin computing: GNC");
      Compute_During_N_Times_1ms (600);
      Put_Line ("End computing: GNC");
   end GNC_Job;

   --------------
   -- TMTC_Job --
   --------------

   procedure TMTC_Job is
   begin
      Put_Line ("Begin computing: TMTC");
      Compute_During_N_Times_1ms (50);
      Put_Line ("End computing: TMTC");
   end TMTC_Job;

   ------------------
   -- GNC_Identity --
   ------------------

   procedure GNC_Identity is
   begin
      if GNC_Welcome then
         Put_Line ("Welcome GNC!");
      else
         Put_Line ("Good bye GNC!");
      end if;

      GNC_Welcome := not GNC_Welcome;
   end GNC_Identity;

   -------------------
   -- TMTC_Identity --
   -------------------

   procedure TMTC_Identity is
   begin
      if TMTC_Welcome then
         Put_Line ("Welcome TMTC!");
      else
         Put_Line ("Good bye TMTC!");
      end if;

      TMTC_Welcome := not TMTC_Welcome;
   end TMTC_Identity;

   --------------
   -- Send_Spg --
   --------------

   procedure Send_Spg
     (Sent_Data   :     POS_Internal_Type;
      Data_Source : out POS_Internal_Type)
   is
   begin
      Data_Source := Sent_Data;
      Put_Line ("Sending Data"
                & POS_Internal_Type'Image (Data_Source));
   end Send_Spg;

   -----------------
   -- Receive_Spg --
   -----------------

   procedure Receive_Spg (Data_Sink : POS_Internal_Type) is
   begin
      Put_Line ("*** RECEIVED DATA ***"
                & POS_Internal_Type'Image (Data_Sink));
   end Receive_Spg;

begin
   declare
      B : Time;
      --  Begin of the measure

      E : Time;
      --  End od the measure

      X : Fixed_12_6 := F_Base;
   begin

      --  Measure N_Base times the same operation 1/X

      B := Clock;
      for I in 1 .. N_Base loop
         X := 1.0 / X;
      end loop;
      E := Clock;

      --  Calculate the number of operation necessary to consume CPU
      --  during 1 sec.

      N_XMS := Natural ((XMS * N_Base) / (E - B));

      --  Redo the measure to obtain a more precise N_XMS value

      B := Clock;
      for I in 1 .. N_XMS loop
         X := 1.0 / X;
      end loop;
      E := Clock;
      N_XMS := Natural ((XMS * N_XMS) / (E - B));
   end;
end Probe;
