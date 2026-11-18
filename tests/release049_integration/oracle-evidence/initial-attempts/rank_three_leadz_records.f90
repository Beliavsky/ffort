program p
use iso_fortran_env, only: output_unit
implicit none
integer::x(2,1,2),u
x(:,1,1)=[0,1]
x(:,1,2)=[2,8]
u=output_unit
write(u,"(2(i2,1x),/)")leadz(x)
end program
