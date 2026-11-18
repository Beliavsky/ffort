program p
implicit none
character(1024),allocatable::owned(:),x(:)
allocate(owned(16383))
call fill(1024,x)
print '(a)','body leaked'
contains
subroutine fill(n,a)
integer,intent(in)::n
character(len=n),allocatable,intent(out)::a(:)
allocate(a(2))
end subroutine
end program
