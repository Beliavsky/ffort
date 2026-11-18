program keyword_oracle
implicit none
integer :: aa(0,3),bb(2,0)
print *,product(dim=1,array=aa),product(array=bb,dim=2)
print *,size(array=product(dim=2,array=aa)),size(array=product(array=bb,dim=1))
end program
