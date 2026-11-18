program p
character(3),allocatable::a(:,:,:)
allocate(a(-1:0,4:4,7:8)); a='abc'
a(0,4,8)='z'
print *,len(a),size(a),lbound(a,3)
print '(4a4)',a
call replace(a)
print *,len(a),size(a),lbound(a,3)
print '(2a4)',a
contains
subroutine replace(x)
character(*),allocatable,intent(out)::x(:,:,:)
allocate(x(1,1,-2:-1)); x='hello'
end subroutine
end program
