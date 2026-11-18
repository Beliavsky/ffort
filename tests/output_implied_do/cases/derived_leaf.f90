program main
implicit none
type t
integer::x
end type
type(t)::a
integer::i
a%x=1
print *, (a,i=1,3)
end program
