program main
implicit none
character(3),allocatable::a(:)
integer::s
allocate(a(2),stat=s); if(s/=0) error stop 1
a='abc'
allocate(a(5),stat=s); if(s==0) error stop 2
print *,size(a),len(a)
print '(2a4)',a
deallocate(a,stat=s); if(s/=0) error stop 3
deallocate(a,stat=s); if(s==0) error stop 4
print *,allocated(a)

end program
