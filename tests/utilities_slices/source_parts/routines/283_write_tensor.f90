subroutine write_tensor(tens,col_labels,outu,fmt_r,fmt_col_labels,title)
real(kind=dp)    , intent(in)           :: tens(:,:,:) ! (nobs,nrows,ncol)
character (len=*), intent(in), optional :: col_labels(:)      ! (ncol)
integer          , intent(in), optional :: outu
character (len=*), intent(in), optional :: fmt_r,fmt_col_labels,title
integer                                 :: i,irow,outu_,iobs,nobs,nrows
character (len=100)                     :: fmt_r_,fmt_col_labels_
call set_optional(fmt_r_  ,"(1000(f0.6,:,','))",fmt_r)
call set_optional(fmt_col_labels_,"(1000(a,:,','))",fmt_col_labels)
nobs  = size(tens,1)
nrows = size(tens,2)
outu_ = default(istdout,outu)
! print*,"fmt_col_labels_= '" // trim(fmt_col_labels_) // "'"
if (present(title))      write (outu_,"(a)") title
if (present(col_labels)) write (outu_,fmt_col_labels_) (trim(col_labels(i)),i=1,size(col_labels))
do iobs=1,nobs
   do irow=1,nrows
      write (outu_,fmt_r_) tens(iobs,irow,:)
   end do
   write (outu_,*)
end do
end subroutine write_tensor
!
