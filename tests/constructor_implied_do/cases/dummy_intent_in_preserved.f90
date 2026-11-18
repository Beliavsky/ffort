program main
implicit none
integer::j
j=88
call work(j)
print *,j
contains
subroutine work(i)
integer,intent(in)::i
integer::a(3)
a=[(i,i=1,3)]
print *,a,i
end subroutine
end program
