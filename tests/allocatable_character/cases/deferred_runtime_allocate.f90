program main
implicit none
character(:),allocatable::a(:,:)
integer::n,s
n=3
allocate(character(len=n+2)::a(-1:0,5:6),stat=s)
a='abc'
print *,s,len(a),lbound(a,1),lbound(a,2)
print '(4a6)',a

end program
