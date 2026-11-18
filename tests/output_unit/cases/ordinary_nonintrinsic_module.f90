module values
implicit none
integer,parameter::a=9
end module
program p
use,non_intrinsic::values,only:a
implicit none
print '(i0)',a
end program
