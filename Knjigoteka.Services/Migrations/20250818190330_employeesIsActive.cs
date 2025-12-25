using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Knjigoteka.Services.Migrations
{
    /// <inheritdoc />
    public partial class employeesIsActive : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "Employees",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "ReservationId",
                table: "Borrowings",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Borrowings_ReservationId",
                table: "Borrowings",
                column: "ReservationId");

            migrationBuilder.AddForeignKey(
                name: "FK_Borrowings_Reservations_ReservationId",
                table: "Borrowings",
                column: "ReservationId",
                principalTable: "Reservations",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Borrowings_Reservations_ReservationId",
                table: "Borrowings");

            migrationBuilder.DropIndex(
                name: "IX_Borrowings_ReservationId",
                table: "Borrowings");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "Employees");

            migrationBuilder.DropColumn(
                name: "ReservationId",
                table: "Borrowings");
        }
    }
}
