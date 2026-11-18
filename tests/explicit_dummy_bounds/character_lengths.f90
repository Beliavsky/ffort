program main
implicit none
character(4)::a(4)
character(2)::b(3)
a=['abcd','efgh','ijkl','mnop']
b=['aa','bb','cc']
call assumed(a,2)
call fixed(b,2)
print *,a,b
contains
subroutine assumed(x,n)
integer,intent(in)::n
character(*),intent(inout)::x(0:n-1)
character(len=len(x))::scratch(size(x))
scratch='q'
x=scratch
end subroutine
subroutine fixed(x,n)
integer,intent(in)::n
character(2),intent(out)::x(n)
x=['xy','zt']
end subroutine
end program
