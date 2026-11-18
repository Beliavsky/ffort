program keyword_oracle
implicit none
integer :: aa(2)
logical :: mm(2)
aa=1
mm=.true.
print *,777
if (.false.) then
print *,maxval(array=aa,dim=.true.)
end if
end program
