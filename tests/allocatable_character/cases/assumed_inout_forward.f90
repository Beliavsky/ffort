program main
implicit none
character(4),allocatable::a(:)
allocate(a(-2:0)); a='x'
call outer(a)
print *,len(a),lbound(a,1),size(a)
print '(2a5)',a
contains
subroutine outer(x)
character(*),allocatable,intent(inout)::x(:)
call inner(x)
end subroutine
subroutine inner(y)
character(*),allocatable,intent(inout)::y(:)
deallocate(y)
allocate(y(7:8))
y='abcdef'
end subroutine

end program
