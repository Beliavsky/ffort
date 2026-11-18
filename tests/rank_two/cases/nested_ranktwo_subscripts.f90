program independent_ranktwo
implicit none
integer :: aa(-1:0,2:4),ii(2,2)
aa=5
ii=2
ii(2,1)=-1
ii(2,2)=4
aa(ii(2,1),ii(2,2))=17
print *, aa,aa(ii(2,1),2)
end program independent_ranktwo
