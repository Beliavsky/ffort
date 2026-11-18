program main
implicit none
character(:),allocatable::a(:)
a=[character(2)::'ab','cd']
a=[character(4)::a,'efgh']
print *,len(a),size(a),lbound(a,1)
print '(3a5)',a

end program
