subroutine print_matrix_real_row_num(xx,col_labels,i1,i2,title,fmt_ir,fmt_icol,fmt_col_labels, &
                                     fmt_header,fmt_trailer,print_col_num,row_num_name,outu)
! print matrix of real numbers with row numbers
real(kind=dp)    , intent(in)           :: xx(:,:)       ! (n,ncol) matrix to be printed
character (len=*), intent(in), optional :: col_labels(:) ! column labels
integer          , intent(in), optional :: i1,i2    ! range of rows to print
character (len=*), intent(in), optional :: title    ! title to print
character (len=*), intent(in), optional :: fmt_ir   ! format to print data
character (len=*), intent(in), optional :: fmt_icol ! format to print column numbers
character (len=*), intent(in), optional :: fmt_col_labels         ! format to print column labels
character (len=*), intent(in), optional :: fmt_header,fmt_trailer ! formats to print before and after printing data
character (len=*), intent(in), optional :: row_num_name
logical          , intent(in), optional :: print_col_num          ! print column numbers
integer          , intent(in), optional :: outu                   ! unit to which data printed
character (len=100)                     :: fmt_ir_,fmt_icol_,fmt_col_labels_
integer                                 :: icol,j,n,outu_
n = size(xx,1)
outu_ = default(istdout,outu)
call set_optional(fmt_ir_,"(i6,1000f12.6)",fmt_ir)
call set_optional(fmt_icol_,"(6x,1000i12)",fmt_icol)
call set_optional(fmt_col_labels_,"(1000a12)",fmt_col_labels)
call write_format(fmt_header,outu_)
if (present(title)) write (outu_,*) trim(title)
if (present(row_num_name)) then
   write (outu_,"(a6)",advance="no") trim(row_num_name)
else
   write (outu_,"(6x)",advance="no")
end if
if (present(col_labels)) write (outu_,fmt_col_labels_) (trim(col_labels(icol)),icol=1,size(col_labels))
if (default(.false.,print_col_num)) write (outu_,fmt_icol_) (icol,icol=1,size(xx,2))
do j=max(1,default(1,i1)),min(n,default(n,i2))
   write (outu_,fmt_ir_) j,xx(j,:)
end do
call write_format(fmt_trailer,outu_)
end subroutine print_matrix_real_row_num
!
