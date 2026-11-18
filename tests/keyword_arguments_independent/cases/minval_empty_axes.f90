program keyword_oracle
implicit none
integer :: aa(0,3),bb(2,0)
print *,minval(dim=1,array=aa),minval(array=bb,dim=2)
print *,size(array=minval(dim=2,array=aa)),size(array=minval(array=bb,dim=1))
end program
