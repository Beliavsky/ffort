program main
implicit none
integer::a(4)
a=make(4)
print *,a
contains
pure function make(n) result(a)
integer,intent(in)::n
integer::i,a(n)
a=[(i*i,i=1,n)]
end function
end program
