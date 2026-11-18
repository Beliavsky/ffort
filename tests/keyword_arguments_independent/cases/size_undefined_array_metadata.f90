program keyword_oracle
implicit none
integer :: aa(-1:0,4:6)
print *,size(array=aa)
print *,size(array=aa,dim=1)
print *,size(dim=1,array=aa)
print *,size(aa,dim=1)
print *,size(DiM=1,ArRaY=aa)
print *,size(array=aa,dim=2)
print *,size(dim=2,array=aa)
print *,size(aa,dim=2)
print *,size(DiM=2,ArRaY=aa)
end program
