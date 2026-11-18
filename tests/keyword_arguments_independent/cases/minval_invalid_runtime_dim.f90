program keyword_oracle
implicit none
integer :: aa(2,2),dd
aa=1
dd=3
print *,777
print *,minval(dim=dd,array=aa)
end program
