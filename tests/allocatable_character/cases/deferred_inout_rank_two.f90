program main
implicit none
character(:),allocatable::a(:,:)
allocate(character(2)::a(2,2));a='ab'
call resize(a)
print *,len(a),size(a),lbound(a,1),lbound(a,2)
print '(2a5)',a
contains
subroutine resize(x)
character(:),allocatable,intent(inout)::x(:,:)
deallocate(x)
allocate(character(4)::x(-3:-2,7:7));x='z'
end subroutine

end program
