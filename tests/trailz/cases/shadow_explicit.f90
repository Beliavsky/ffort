module iso_fortran_env
implicit none
integer,parameter::int8=77
integer,parameter::integer_kinds(2)=[11,22]
end module iso_fortran_env
program p
use,intrinsic::iso_fortran_env,only:int8,integer_kinds
implicit none
print *,int8,integer_kinds
end program p
