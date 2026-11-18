program keyword_oracle
implicit none
integer :: aa(0,3),bb(2,0)
print *,sum(dim=1,array=aa),sum(array=bb,dim=2)
print *,size(array=sum(dim=2,array=aa)),size(array=sum(array=bb,dim=1))
end program
