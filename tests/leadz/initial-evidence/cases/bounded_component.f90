program p
implicit none
type t
integer::a
end type
type(t)::x
x%a=1
print *,leadz(x%a)
end program
