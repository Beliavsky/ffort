program p
implicit none
type::dt
integer::a=7
end type
type(dt)::x
print '(i0)',x%a
end program
