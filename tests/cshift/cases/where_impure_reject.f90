program p
implicit none
integer::a(3),i
a=1
where(a>0) a=cshift(a,shift())
print *, "PASS"
contains
integer function shift() result(r)
real::x
call random_number(x)
r=int(x*3.0)
end function
end program
