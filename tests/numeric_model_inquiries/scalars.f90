program model_scalars
implicit none
integer :: i4
integer(8) :: i8
real :: r4
real(8) :: r8
integer, parameter :: base = radix(r8)
integer(8), parameter :: limit = huge(i8)
real, parameter :: eps = epsilon(r4), least=tiny(r4), largest=huge(r4)
real(8), parameter :: eps8=epsilon(r8), least8=tiny(r8), largest8=huge(r8)
print *, base, limit, huge(i4), radix(i4), radix(i8), radix(r4)
print *, eps, least, largest, eps8, least8, largest8
print *, kind(epsilon(r4)),kind(epsilon(r8)),kind(tiny(r4)),kind(tiny(r8))
print *, kind(huge(i4)),kind(huge(i8)),kind(huge(r4)),kind(huge(r8)),kind(radix(i8))
print *, epsilon(x=r8),tiny(x=r8),huge(x=i8),radix(x=r8)
print *, floor(2.0-epsilon(0.0)), huge(0_8)-1_8
end program
