program p
implicit none

print *,nearest(f(),1.)>1.,spacing(f())==epsilon(1.)
contains
pure function f() result(x)
real::x(2)
x=1
end function
end program
