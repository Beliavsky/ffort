program kinds_keyword_declaration
implicit none
integer,parameter :: wp=selected_real_kind(radix=2,r=307,p=15)
real(wp) :: x
real(selected_real_kind(r=307)) :: y
x=1.5_wp
y=2.5_wp
call take(x)
call take(y)
contains
subroutine take(v)
real(wp),intent(in)::v
print *, kind(v),v
end subroutine
end program
