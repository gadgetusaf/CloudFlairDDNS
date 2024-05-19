# Cloudflare DNS Updater

This project provides a Docker container that automatically updates Cloudflare DNS records with the current public IP address of the host machine.

## Usage

1. Build the Docker image:
   ```bash
   docker build -t cloudflare-dns-updater .
   ```

2. Run the container for the first time to retrieve the DNS records:
   ```bash
   docker run -it --rm -e EMAIL_ADDRESS="your_email" -e API_TOKEN="your_token" -v /path/to/data:/app/data cloudflare-dns-updater
   ```

3. Update the `dns_records.csv` file in the mounted volume with the domains that need to be updated.

4. Restart the container to start the update process:
   ```bash
   docker run -d --restart always -e EMAIL_ADDRESS="your_email" -e API_TOKEN="your_token" -v /path/to/data:/app/data cloudflare-dns-updater
   ```

   With the `--restart always` flag, Docker will automatically restart the container if it exits or if the Docker daemon restarts. This ensures that the container is always running and performing the DNS updates every 10 minutes.

## Configuration

The following environment variables are required to run the container:

- `EMAIL_ADDRESS`: Your Cloudflare account email address.
- `API_TOKEN`: Your Cloudflare API token with the necessary permissions to update DNS records.

Additionally, you need to mount a volume to `/app/data` in the container. This volume should contain a `dns_records.csv` file with the list of domains to be updated.

## License

This project is licensed under the [MIT License](LICENSE).