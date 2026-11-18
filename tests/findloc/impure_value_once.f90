module m
integer::calls=0
contains
impure elemental integer function wanted()
calls=calls+1
wanted=2
end function
end module
program p
use m
integer::a(4)=[2,1,2,3]
print *,findloc(a,wanted(),dim=1)
print *,calls
end program
