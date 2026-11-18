program keyword_oracle
implicit none
integer :: aa(0,3),bb(2,0)
print *,maxval(dim=1,array=aa),maxval(array=bb,dim=2)
print *,size(array=maxval(dim=2,array=aa)),size(array=maxval(array=bb,dim=1))
end program
