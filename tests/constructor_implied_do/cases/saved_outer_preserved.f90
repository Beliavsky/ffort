program main
implicit none

call work()
call work()
contains
subroutine work()
integer,save::i=88
integer::a(3)
a=[(i,i=1,3)]
print *,a,i
i=i+1
end subroutine
end program
