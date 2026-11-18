program p
character(:),allocatable::a(:,:,:)
a=make()
print *,len(a),size(a),lbound(a,3)
print '(2a5)',a
contains
function make() result(x)
character(:),allocatable::x(:,:,:)
allocate(character(4)::x(1,1,5:6)); x='test'
end function
end program
