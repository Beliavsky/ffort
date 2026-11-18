! SPDX-License-Identifier: MIT
! Original declaration slice from urbanjost/M_intrinsics demo_unpack.f90,
! commit fc14233036d910e3678d350efc24609e11475067. See README.md and LICENSE-M_intrinsics.
! This exercises the initializers only, not UNPACK or the original I/O helper.
program demo_unpack_initializers
      implicit none
      logical,parameter :: T=.true., F=.false.
      integer,parameter :: rows=3, cols=3
      integer           :: i
      logical           :: mask(rows,cols) = reshape([ &
         T, F, F, &
         F, T, F, &
         F, F, T  &
      ],[3,3])
      integer :: field(rows,cols) = reshape([ &
         1, 2, 3, &
         4, 5, 6, &
         7, 8, 9  &
      ],[3,3])
print *, mask
print *, field
end program
