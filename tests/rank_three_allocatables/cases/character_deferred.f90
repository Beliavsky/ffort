program p
character(:),allocatable::a(:,:,:),b(:,:,:)
allocate(character(2)::a(-1:0,4:4,7:8)); a='ab'
allocate(character(4)::b(3:4,5:5,9:10)); b='test'
a=b
print *,len(a),lbound(a,1),lbound(a,2),lbound(a,3),size(a)
a='q'
print *,len(a),lbound(a,3),size(a)
call resize(a)
print *,len(a),lbound(a,3),size(a)
print '(2a6)',a
contains
subroutine resize(x)
character(:),allocatable,intent(inout)::x(:,:,:)
deallocate(x)
allocate(character(5)::x(1,1,-3:-2)); x='hello'
end subroutine
end program
