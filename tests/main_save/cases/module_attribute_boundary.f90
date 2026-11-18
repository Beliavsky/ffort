module m
implicit none
integer,save::a(2)=[1,2]
end module
program p
use m
print *,a
end program
