program p
implicit none

call work()
contains
subroutine work()
integer::aa(2)=[1,2]
print *,aa
end subroutine
end program p
