program p
implicit none
integer::n
n=3
call show('a ',n)
n=0
call show('xx',n)
contains
subroutine show(s,n)
character(*),intent(in)::s
integer,intent(in)::n
print *,len(repeat(s,n))
print '(a)', '<'//repeat(s,n)//'>'
end subroutine
end program
