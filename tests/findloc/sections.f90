program p
implicit none
integer::a(-1:2,0:2)
a=reshape([1,2,3,4,5,6,7,8,9,10,11,12],[4,3])
print *,findloc(a(2:-1:-1,2:0:-1),7),findloc(a(:,1),7,dim=1)
print *,findloc(a(2:-1:-2,:),8,dim=2)
end program
