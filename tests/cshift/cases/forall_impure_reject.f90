program p
implicit none
integer::a(3),i
a=1
forall(i=1:3) a(i)=sum(cshift(a,shift()))
print *, "PASS"
contains
integer function shift() result(r)
real::x
call random_number(x)
r=int(x*3.0)
end function
end program
