      program demo_not
      implicit none
      integer :: i
        ! basics
         i=-13741
         print *,'the input value',i,'represented in bits is'
         write(*,'(1x,b32.32,1x,i0)') i, i
         i=not(i)
         print *,'on output it is',i
         write(*,'(1x,b32.32,1x,i0)') i, i
         print *, " on a two's complement machine flip the bits and add 1"
         print *, " to get the value with the sign changed, for example."
         print *, 1234, not(1234)+1
         print *, -1234, not(-1234)+1
         print *, " of course 'x=-x' works just fine and more generally."
         !
         call bitmask_example()
      contains

      subroutine bitmask_example() ! Creating a Bitmask with NOT() and IAND()

      ! A real-world use case for NOT() is combining it  with IAND() (bitwise
      ! AND) to clear specific bits in a bitmask. In modern Fortran there
      ! procedures like IBCLR(3f) to do such operations.

      integer :: flags, mask, cleared_flags

         ! Binary: 00001111 (in decimal: 15)
         flags = 15

         ! We want to clear the 3rd bit (binary: 00000100, decimal: 4)
         mask = 4

         ! NOT(mask) turns 00000100 into 11111011
         ! IAND then preserves everything EXCEPT the 3rd bit
         cleared_flags = IAND(flags, NOT(mask))

         print *, "Resulting value: ", cleared_flags ! Outputs: 11 (binary: 00001011)
      end subroutine bitmask_example

      end program demo_not
